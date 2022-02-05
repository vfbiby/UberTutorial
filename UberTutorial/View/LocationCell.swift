//
//  LocationCell.swift
//  UberTutorial
//
//  Created by 张铁林 on 2022/2/5.
//

import UIKit

class LocationCell: UITableViewCell {
    
    // MARK: - Properties
    
    private let titleLable: UILabel = {
        let label = UILabel()
        label.text = "123 Main Street"
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    private let addressLable: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "123 Main Street Washinton, DC"
        label.textColor = .lightGray
        return label
    }()
    
    // MARK: - Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        let stack = UIStackView(arrangedSubviews: [titleLable, addressLable])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 4
        
        addSubview(stack)
        stack.centerY(inView: self, leftAnchor: leftAnchor, paddingLeft: 12)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
